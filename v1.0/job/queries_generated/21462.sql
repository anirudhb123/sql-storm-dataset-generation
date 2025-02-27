WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        tk.keyword, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(tk.id) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword tk ON mk.keyword_id = tk.id
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS unique_cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS company_names,
        SUM(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS production_company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rd.unique_cast_count,
        cd.company_names,
        cd.production_company_count,
        rk.keyword_count,
        CASE 
            WHEN rk.keyword_count > 1 THEN 'High Keyword Diversity'
            ELSE 'Low Keyword Diversity'
        END AS keyword_diversity
    FROM 
        RankedMovies rm
    JOIN 
        CastDetails rd ON rm.movie_id = rd.movie_id
    JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id
    WHERE 
        rm.production_year >= 2000
),
FinalSelection AS (
    SELECT 
        fm.*,
        ROW_NUMBER() OVER (ORDER BY fm.production_year DESC, fm.unique_cast_count DESC) AS rank
    FROM 
        FilteredMovies fm
    WHERE 
        fm.production_company_count > 0
)
SELECT 
    F.*,
    CASE 
        WHEN F.unique_cast_count IS NULL THEN 'No Cast Information'
        ELSE 'Cast Info Available'
    END AS cast_info_status,
    COALESCE(F.cast_names, 'Unknown') AS cast_names_display
FROM 
    FinalSelection F
WHERE 
    F.rank <= 10
ORDER BY 
    F.production_year DESC, F.title;
