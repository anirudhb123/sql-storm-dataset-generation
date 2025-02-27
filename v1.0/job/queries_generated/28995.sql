WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id, 
        a.title, 
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_within_year
    FROM 
        aka_title a 
    WHERE 
        a.production_year IS NOT NULL
),
CastCounts AS (
    SELECT 
        c.movie_id, 
        COUNT(c.person_id) AS cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
FrequentRoles AS (
    SELECT 
        r.role, 
        COUNT(*) AS role_count
    FROM 
        role_type r
    JOIN 
        cast_info c ON r.id = c.role_id
    GROUP BY 
        r.role
    HAVING 
        COUNT(*) > 10
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieTitleInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        i.info AS synopsis
    FROM 
        title t
    LEFT JOIN 
        movie_info i ON t.id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'synopsis' LIMIT 1)
),
FinalBenchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cc.cast_count,
        ARRAY_AGG(DISTINCT cr.role) AS frequent_roles,
        cd.company_name,
        cd.company_type,
        mti.synopsis,
        rm.rank_within_year
    FROM 
        RankedMovies rm
    JOIN 
        CastCounts cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        FrequentRoles cr ON cr.role IN (SELECT role FROM role_type WHERE role IS NOT NULL)
    LEFT JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        MovieTitleInfo mti ON rm.movie_id = mti.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, cc.cast_count, cd.company_name, cd.company_type, mti.synopsis, rm.rank_within_year
)
SELECT 
    *
FROM 
    FinalBenchmark
ORDER BY 
    production_year DESC, rank_within_year;
