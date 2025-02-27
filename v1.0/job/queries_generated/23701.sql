WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_title,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS cast_member_count,
        STRING_AGG(aka.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name aka ON ci.person_id = aka.person_id
    GROUP BY 
        ci.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names,
        STRING_AGG(ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
KeyMovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mi.info, 'No information') AS movie_info,
        COALESCE(KI.keyword, 'No keywords') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword KI ON mk.keyword_id = KI.id
),
FinalBenchmark AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.rank_title,
        r.total_movies,
        COALESCE(cd.cast_member_count, 0) AS cast_member_count,
        COALESCE(cd.cast_names, 'No cast') AS cast_names,
        COALESCE(mc.company_names, 'No companies') AS company_names,
        COALESCE(mc.company_types, 'No types') AS company_types,
        COALESCE(km.movie_info, 'No Info') AS movie_info,
        COALESCE(km.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        CastDetails cd ON r.movie_id = cd.movie_id
    LEFT JOIN 
        MovieCompanies mc ON r.movie_id = mc.movie_id
    LEFT JOIN 
        KeyMovieInfo km ON r.movie_id = km.movie_id
)
SELECT 
    production_year,
    AVG(cast_member_count) AS avg_cast_members,
    STRING_AGG(DISTINCT title || ' (' || production_year || ')', ', ') AS movies_list,
    COUNT(*) AS total_movies,
    SUM(CASE 
            WHEN movie_info LIKE '%epic%' THEN 1 
            ELSE 0 
        END) AS epic_movies
FROM 
    FinalBenchmark
GROUP BY 
    production_year
HAVING 
    COUNT(*) > 1
ORDER BY 
    production_year DESC;
