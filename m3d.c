#define _CRT_SECURE_NO_WARNINGS

extern void* m3d_allocator_malloc(size_t size);
extern void* m3d_allocator_realloc(void* old_pointer, size_t new_size);
extern void m3d_allocator_free(void* old_pointer);

#define M3D_MALLOC  m3d_allocator_malloc
#define M3D_REALLOC m3d_allocator_realloc
#define M3D_FREE    m3d_allocator_free

#define M3D_IMPLEMENTATION
#include "m3d.h"

#ifdef ASSERTIONS

#include "stdio.h"

#define ODIN_ASSERT(_C_Type_, _Odin_Type_) fprintf(file, "#assert(size_of(%s) == %llu)\n", _Odin_Type_, sizeof(_C_Type_))

int main()
{
    FILE* file = fopen("assertions.odin", "w");
    fprintf(file, "package m3d\n\n");

    ODIN_ASSERT(M3D_FLOAT, "FLOAT");
    ODIN_ASSERT(M3D_INDEX, "INDEX");
    ODIN_ASSERT(M3D_VOXEL, "VOXEL");
    ODIN_ASSERT(m3dhdr_t, "hdr_t");
    ODIN_ASSERT(m3dchunk_t, "chunk_t");
    ODIN_ASSERT(m3dti_t, "ti_t");
    ODIN_ASSERT(m3dtx_t, "tx_t");
    ODIN_ASSERT(m3dw_t, "w_t");
    ODIN_ASSERT(m3db_t, "b_t");
    ODIN_ASSERT(m3dv_t, "v_t");
    ODIN_ASSERT(m3dpd_t, "pd_t");
    ODIN_ASSERT(m3dp_t, "p_t");
    ODIN_ASSERT(m3dm_t, "m_t");
    ODIN_ASSERT(m3dvi_t, "vi_t");
    ODIN_ASSERT(m3dvt_t, "vt_t");
    ODIN_ASSERT(m3dvx_t, "vx_t");
    ODIN_ASSERT(m3dcd_t, "cd_t");
    ODIN_ASSERT(m3dc_t, "c_t");
    ODIN_ASSERT(m3dh_t, "h_t");
    ODIN_ASSERT(m3dl_t, "l_t");
    ODIN_ASSERT(m3dtr_t, "tr_t");
    ODIN_ASSERT(m3da_t, "a_t");
    ODIN_ASSERT(m3di_t, "i_t");
    ODIN_ASSERT(m3d_t, "m3d_t");

    fclose(file);
    return 0;
}

#endif
