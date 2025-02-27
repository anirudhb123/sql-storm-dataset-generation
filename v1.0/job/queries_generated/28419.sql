WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        GROUP_CONCAT(DISTINCT a.name) AS cast_names,
        SUM(CASE WHEN mc.company_type_id = 1 THEN 1 ELSE 0 END) AS production_companies_count,
        AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND cc.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
), RankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_names,
        production_companies_count,
        avg_info_length,
        RANK() OVER (ORDER BY production_year DESC, avg_info_length DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    rm.keyword,
    rm.cast_names,
    rm.production_companies_count,
    rm.avg_info_length
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank;
