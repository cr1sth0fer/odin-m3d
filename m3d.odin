
package m3d

import "core:c"
import "core:mem"

allocator: mem.Allocator

@(export)
m3d_allocator_malloc :: proc "c" (size: c.size_t) -> rawptr {
    context = {}
    data, _ := mem.alloc(int(size), allocator = allocator)
    return data
}

@(export)
m3d_allocator_realloc :: proc "c" (old_pointer: rawptr, new_size: c.size_t) -> rawptr {
    context = {}
    info := mem.query_info(old_pointer, allocator)
    data, _ := mem.resize(old_pointer, info.size.(int), int(new_size), allocator = allocator)
    return data
}

@(export)
m3d_allocator_free :: proc "c" (old_pointer: rawptr) {
    context = {}
    mem.free(old_pointer, allocator = allocator)
}

APIVERSION :: 0x0100

DOUBLE :: #config(M3D_DOUBLE, false)
when DOUBLE
{
    FLOAT :: f64
}
else
{
    FLOAT :: f32
}

SMALLINDEX :: #config(M3D_SMALLINDEX, false)
when !SMALLINDEX
{
    INDEX :: u32
    VOXEL :: u16
    UNDEF :: 0xffffffff
    INDEXMAX :: 0xfffffffe
    VOXUNDEF :: 0xffff
    VOXCLEAR :: 0xfffe
}
else
{
    INDEX :: u16
    VOXEL :: u8
    UNDEF :: 0xffff
    INDEXMAX :: 0xfffe
    VOXUNDEF :: 0xff
    VOXCLEAR :: 0xfe
}

NOTDEFINED :: 0xffffffff

NUMBONE      :: #config(MD3_NUMBONE, 4)
BONEMAXLEVEL :: #config(MD3_BONEMAXLEVEL, 64)

VERTEXTYPE :: #config(M3D_VERTEXTYPE, false)
ASCII :: #config(M3D_ASCII, false)
VERTEXMAX :: #config(M3D_VERTEXMAX, false)
CMDMAXARG :: #config(M3D_CMDMAXARG, 8) /* if you increase this, add more arguments to the macro below */

hdr_t :: struct #packed
{
    magic: [4]u8,
    length: u32,
    scale: f32,    /* deliberately not m3d.FLOAT */
    types: u32,
}

chunk_t :: struct #packed
{
    magic: [4]u8,
    length: u32,
}

/* textmap entry */
ti_t :: struct
{
    u, v: FLOAT,
}
textureindex_t :: ti_t

/* texture */
tx_t :: struct
{
    name: cstring,          /* texture name */
    d: [^]u8,               /* pixels data */
    w: u16,                 /* width */
    h: u16,                 /* height */
    f: u8,                  /* format, 1 = grayscale, 2 = grayscale+alpha, 3 = rgb, 4 = rgba */
}
texturedata_t :: tx_t

w_t :: struct
{
    vertexid: INDEX,
    weight: FLOAT,
}
weight_t :: w_t

/* bone entry */
b_t :: struct
{
    parent: INDEX,           /* parent bone index */
    name: cstring,         /* name for this bone */
    pos: INDEX,              /* vertex index position */
    ori: INDEX,              /* vertex index orientation (quaternion) */
    numweight: INDEX,        /* number of controlled vertices */
    weight: [^]w_t,        /* weights for those vertices */
    mat4: [16]FLOAT,         /* transformation matrix */
}
bone_t :: b_t

/* skin: bone per vertex entry */
s_t :: struct
{
    boneid: [NUMBONE]INDEX,
    weight: [NUMBONE]FLOAT,
}
skin_t :: s_t

when VERTEXTYPE
{
    /* vertex entry */
    v_t :: struct
    {
        x: FLOAT,                /* 3D coordinates and weight */
        y: FLOAT,
        z: FLOAT,
        w: FLOAT,
        color: u32,             /* default vertex color */
        skinid: INDEX,           /* skin index */
        type: u8,
    }
}
else
{
    /* vertex entry */
    v_t :: struct
    {
        x: FLOAT,                /* 3D coordinates and weight */
        y: FLOAT,
        z: FLOAT,
        w: FLOAT,
        color: u32,             /* default vertex color */
        skinid: INDEX,           /* skin index */
    }
}
vertex_t :: v_t

/* material property formats */
pf_t :: enum u8
{
    color,
    uint8,
    uint16,
    uint32,
    float,
    map_
}

when ASCII
{
    pd_t :: struct
    {
        format: pf_t,
        id: u8,
        key: cstring,
    }
}
else
{
    pd_t :: struct
    {
        format: pf_t,
        id: u8,
    }
}

/* material property types */
/* You shouldn't change the first 8 display and first 4 physical property. Assign the rest as you like. */
p_e :: enum u8
{
    Kd = 0,                /* scalar display properties */
    Ka,
    Ks,
    Ns,
    Ke,
    Tf,
    Km,
    d,
    il,

    Pr = 64,               /* scalar physical properties */
    Pm,
    Ps,
    Ni,
    Nt,

    map_Kd = 128,          /* textured display map properties */
    map_Ka,
    map_Ks,
    map_Ns,
    map_Ke,
    map_Tf,
    map_Km, /* bump map */
    map_D,
    map_N,  /* normal map */

    map_Pr = 192,          /* textured physical map properties */
    map_Pm,
    map_Ps,
    map_Ni,
    map_Nt
}

/* aliases */
p_bump :: p_e.map_Km
p_map_il :: p_e.map_N
p_refl :: p_e.map_Pm

/* material property */
p_t :: struct
{
    type: p_e,               /* property type, see "m3dp_*" enumeration */
    value: struct #raw_union
    {
        color: u32,         /* if value is a color, m3dpf_color */
        num: u32,           /* if value is a number, m3dpf_uint8, m3pf_uint16, m3dpf_uint32 */
        fnum: f32,          /* if value is a floating point number, m3dpf_float */
        textureid: INDEX,   /* if value is a texture, m3dpf_map */
    },
}
property_t :: p_t

/* material entry */
m_t :: struct
{
    name: cstring,      /* name of the material */
    numprop: u8,        /* number of properties */
    prop: [^]p_t,       /* properties array */
}
material_t :: m_t

when VERTEXMAX
{
    /* face entry */
    f_t :: struct
    {
        materialid: INDEX,       /* material index */
        vertex: [3]INDEX,        /* 3D points of the triangle in CCW order */
        normal: [3]INDEX,        /* normal vectors */
        texcoord: [3]INDEX,      /* UV coordinates */
        paramid: INDEX,         /* parameter index */
        vertmax: [3]INDEX,      /* maximum 3D points of the triangle in CCW order */
    }
}
else
{
    /* face entry */
    f_t :: struct
    {
        materialid: INDEX,       /* material index */
        vertex: [3]INDEX,        /* 3D points of the triangle in CCW order */
        normal: [3]INDEX,        /* normal vectors */
        texcoord: [3]INDEX,      /* UV coordinates */
    }
}
face_t :: f_t

vi_t :: struct
{
    count: u16,
    name: cstring,
}
voxelitem_t :: vi_t
parameter_t :: vi_t

/* voxel types (voxel palette) */
vt_t :: struct
{
    name: cstring,          /* technical name of the voxel */
    rotation: u8,           /* rotation info */
    voxshape: u16,          /* voxel shape */
    materialid: INDEX,      /* material index */
    color: u32,             /* default voxel color */
    skinid: INDEX,          /* skin index */
    numitem: u8,            /* number of sub-voxels */
    item: [^]vi_t,          /* list of sub-voxels */
}
voxeltype_t :: vt_t

/* voxel data blocks */
vx_t :: struct
{
    name: cstring,          /* name of the block */
    x, y, z: i32,           /* position */
    w, h, d: u32,           /* dimension */
    uncertain: u8,          /* probability */
    groupid: u8,            /* block group id */
    data: [^]VOXEL,         /* voxel data, indices to voxel type */
}
voxel_t :: vx_t

/* shape command types. must match the row in m3d_commandtypes */
c_e :: enum u8
{
    /* special commands */
    use = 0,               /* use material */
    inc,                   /* include another shape */
    mesh,                  /* include part of polygon mesh */
    /* approximations */
    div,                   /* subdivision by constant resolution for both u, v */
    sub,                   /* subdivision by constant, different for u and v */
    len,                   /* spacial subdivision by maxlength */
    dist,                  /* subdivision by maxdistance and maxangle */
    /* modifiers */
    degu,                  /* degree for both u, v */
    deg,                   /* separate degree for u and v */
    rangeu,                /* range for u */
    range,                 /* range for u and v */
    paru,                  /* u parameters (knots) */
    parv,                  /* v parameters */
    trim,                  /* outer trimming curve */
    hole,                  /* inner trimming curve */
    scrv,                  /* spacial curve */
    sp,                    /* special points */
    /* helper curves */
    bez1,                  /* Bezier 1D */
    bsp1,                  /* B-spline 1D */
    bez2,                  /* bezier 2D */
    bsp2,                  /* B-spline 2D */
    /* surfaces */
    bezun,                 /* Bezier 3D with control, UV, normal */
    bezu,                  /* with control and UV */
    bezn,                  /* with control and normal */
    bez,                   /* control points only */
    nurbsun,               /* B-spline 3D */
    nurbsu,
    nurbsn,
    nurbs,
    conn,                 /* connect surfaces */
    /* geometrical */
    line,
    polygon,
    circle,
    cylinder,
    shpere,
    torus,
    cone,
    cube,
}

/* shape command argument types */
cp_e :: enum u8
{
    mi_t = 1,             /* material index */
    hi_t,                 /* shape index */
    fi_t,                 /* face index */
    ti_t,                 /* texture map index */
    vi_t,                 /* vertex index */
    qi_t,                 /* vertex index for quaternions */
    vc_t,                 /* coordinate or radius, float scalar */
    i1_t,                 /* int8 scalar */
    i2_t,                 /* int16 scalar */
    i4_t,                 /* int32 scalar */
    va_t,                  /* variadic arguments */
}

when ASCII
{
    cd_t :: struct
    {
        key: cstring,
        p: u8,
        a: [CMDMAXARG]u8,
    }
}
else
{
    cd_t :: struct
    {
        p: u8,
        a: [CMDMAXARG]u8,
    }
}

/* shape command */
c_t :: struct
{
    type: u16,              /* shape type */
    arg: [^]u32,            /* arguments array */
}
shapecommand_t :: c_t

/* shape entry */
h_t :: struct
{
    name: cstring,          /* name of the mathematical shape */
    group: INDEX,           /* group this shape belongs to or -1 */
    numcmd: u32,            /* number of commands */
    cmd: [^]c_t,            /* commands array */
}
shape_t :: h_t

/* label entry */
l_t :: struct
{
    name: cstring,          /* name of the annotation layer or NULL */
    lang: cstring,          /* language code or NULL */
    text: cstring,          /* the label text */
    color: u32,             /* color */
    vertexid: INDEX,        /* the vertex the label refers to */
}
label_t :: l_t

/* frame transformations / working copy skeleton entry */
tr_t :: struct
{
    boneid: INDEX,           /* selects a node in bone hierarchy */
    pos: INDEX,              /* vertex index new position */
    ori: INDEX,              /* vertex index new orientation (quaternion) */
}
transform_t :: tr_t

/* animation frame entry */
fr_t :: struct
{
    msec: u32,              /* frame's position on the timeline, timestamp */
    numtransform: INDEX,    /* number of transformations in this frame */
    transform: [^]tr_t,     /* transformations */
}
frame_t :: fr_t

/* model action entry */
a_t :: struct
{
    name: cstring,                 /* name of the action */
    durationmsec: u32,      /* duration in millisec (1/1000 sec) */
    numframe: INDEX,         /* number of frames in this animation */
    frame: [^]fr_t,             /* frames array */
}
action_t :: a_t

/* inlined asset */
i_t :: struct
{
    name: cstring,                 /* asset name (same pointer as in texture[].name) */
    data: [^]u8,              /* compressed asset data */
    length: u32,            /* compressed data length */
}
inlinedasset_t :: i_t

/*** in-memory model structure ***/
FLG_FREERAW :: (1<<0)
FLG_FREESTR :: (1<<1)
FLG_MTLLIB  :: (1<<2)
FLG_GENNORM :: (1<<3)

when VERTEXMAX
{
    m3d_t :: struct
    {
        raw: [^]hdr_t,              /* pointer to raw data */
        flags: u8,                  /* internal flags */
        errcode: i8,                /* returned error code */
        vc_s, vi_s, si_s, ci_s, ti_s, bi_s, nb_s, sk_s, fc_s, hi_s, fi_s, vd_s, vp_s: u8,  /* decoded sizes for types */
        name: cstring,              /* name of the model, like "Utah teapot" */
        license: cstring,           /* usage condition or license, like "MIT", "LGPL" or "BSD-3clause" */
        author: cstring,            /* nickname, email, homepage or github URL etc. */
        desc: cstring,              /* comments, descriptions. May contain '\n' newline character */
        scale: FLOAT,               /* the model's bounding cube's size in SI meters */
        numcmap: INDEX,
        cmap: [^]u32,               /* color map */
        numtmap: INDEX,
        tmap: [^]ti_t,              /* texture map indices */
        numtexture: INDEX,
        texture: [^]tx_t,           /* uncompressed textures */
        numbone: INDEX,
        bone: [^]b_t,               /* bone hierarchy */
        numvertex: INDEX,
        vertex: [^]v_t,             /* vertex data */
        numskin: INDEX,
        skin: [^]s_t,               /* skin data */
        nummaterial: INDEX,
        material: [^]m_t,           /* material list */
        numparam: INDEX,
        param: [^]vi_t,             /* parameters and their values list */
        numface: INDEX,
        face: [^]f_t,               /* model face, polygon (triangle) mesh */
        numvoxtype: INDEX,
        voxtype: [^]vt_t,           /* model face, voxel types */
        numvoxel: INDEX,
        voxel: [^]vx_t,             /* model face, cubes compressed into voxels */
        numshape: INDEX,
        shape: [^]h_t,              /* model face, shape commands */
        numlabel: INDEX,
        label: [^]l_t,              /* annotation labels */
        numaction: INDEX,
        action: [^]a_t,             /* action animations */
        numinlined: INDEX,
        inlined: [^]i_t,            /* inlined assets */
        numextra: INDEX,
        extra: [^]^chunk_t,         /* unknown chunks, application / engine specific data probably */
        preview: i_t,               /* preview chunk */
    }
}
else
{
    m3d_t :: struct
    {
        raw: [^]hdr_t,              /* pointer to raw data */
        flags: u8,                  /* internal flags */
        errcode: i8,                /* returned error code */
        vc_s, vi_s, si_s, ci_s, ti_s, bi_s, nb_s, sk_s, fc_s, hi_s, fi_s, vd_s, vp_s: u8,  /* decoded sizes for types */
        name: cstring,              /* name of the model, like "Utah teapot" */
        license: cstring,           /* usage condition or license, like "MIT", "LGPL" or "BSD-3clause" */
        author: cstring,            /* nickname, email, homepage or github URL etc. */
        desc: cstring,              /* comments, descriptions. May contain '\n' newline character */
        scale: FLOAT,               /* the model's bounding cube's size in SI meters */
        numcmap: INDEX,
        cmap: [^]u32,               /* color map */
        numtmap: INDEX,
        tmap: [^]ti_t,              /* texture map indices */
        numtexture: INDEX,
        texture: [^]tx_t,           /* uncompressed textures */
        numbone: INDEX,
        bone: [^]b_t,               /* bone hierarchy */
        numvertex: INDEX,
        vertex: [^]v_t,             /* vertex data */
        numskin: INDEX,
        skin: [^]s_t,               /* skin data */
        nummaterial: INDEX,
        material: [^]m_t,           /* material list */
        numface: INDEX,
        face: [^]f_t,               /* model face, polygon (triangle) mesh */
        numvoxtype: INDEX,
        voxtype: [^]vt_t,           /* model face, voxel types */
        numvoxel: INDEX,
        voxel: [^]vx_t,             /* model face, cubes compressed into voxels */
        numshape: INDEX,
        shape: [^]h_t,              /* model face, shape commands */
        numlabel: INDEX,
        label: [^]l_t,              /* annotation labels */
        numaction: INDEX,
        action: [^]a_t,             /* action animations */
        numinlined: INDEX,
        inlined: [^]i_t,            /* inlined assets */
        numextra: INDEX,
        extra: [^]^chunk_t,         /* unknown chunks, application / engine specific data probably */
        preview: i_t,               /* preview chunk */
    }
}

/* read file contents into buffer */
read_t :: #type proc "c" (filename: cstring, size: ^u32) -> [^]u8

/* free file contents buffer */
free_t :: #type proc "c" (buffer: rawptr)

/* interpret texture script */
txsc_t :: #type proc "c" (name: cstring, script: rawptr, len: u32, output: ^tx_t) -> i32

/* interpret surface script */
prsc_t :: #type proc "c" (name: cstring, script: rawptr, len: u32, model: ^m3d_t) -> i32

when ODIN_OS == .Windows && ODIN_ARCH == .amd64
{
    foreign import m3d "m3d_windows_amd64.lib"
}

@(default_calling_convention="c")
foreign m3d
{
    @(link_name="m3d_load")
    _load :: proc(data: [^]u8, readfilecb: read_t, freecb: free_t, mtllib: ^m3d_t) -> ^m3d_t ---

    @(link_name="m3d_save")
    save :: proc(model: ^m3d_t, quality, flags: i32, size: ^u32) -> [^]u8 ---

    @(link_name="m3d_free")
    free :: proc(model: ^m3d_t) ---
    
    /* generate animation pose skeleton */
    @(link_name="m3d_frame")
    frame :: proc(model: ^m3d_t, actionid: INDEX, frameid: INDEX, skeleton: ^tr_t) -> ^tr_t ---

    @(link_name="m3d_pose")
    pose :: proc(model: ^m3d_t, actionid: INDEX, msec: u32) -> ^b_t ---
    
    /* private prototypes used by both importer and exporter */
    @(link_name="_m3d_safestr")
    _m3d_safestr :: proc(in_: cstring, morelines: i32) -> cstring ---
}

// load :: proc(data: [^]u8, readfilecb: read_t, freecb: free_t, mtllib: ^m3d_t, allocator := context.allocator) -> ^m3d_t
// {
// }
