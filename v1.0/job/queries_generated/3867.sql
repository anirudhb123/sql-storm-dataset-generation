WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        ak.name AS actor_name,
        ak.surname_pcode,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COALESCE(mi.info, 'No Info') AS movie_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.title_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON rm.title_id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON rm.title_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot' LIMIT 1)
    WHERE 
        rm.rn <= 3
    GROUP BY 
        rm.title_id, rm.title, rm.production_year, ak.name, ak.surname_pcode, mi.info
),
FilteredMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        actor_name,
        surname_pcode,
        keyword_count,
        movie_info,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank_by_keywords
    FROM 
        MovieDetails
)
SELECT 
    f.title_id,
    f.title,
    f.production_year,
    f.actor_name,
    f.surname_pcode,
    f.keyword_count,
    f.movie_info,
    COALESCE(ct.kind, 'Unknown') AS company_type
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_companies mc ON f.title_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    f.rank_by_keywords = 1
ORDER BY 
    f.production_year DESC, f.keyword_count DESC;
