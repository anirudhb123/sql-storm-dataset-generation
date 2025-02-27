WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        k.keyword AS keyword,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS cast_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT pi.info_type_id) AS info_count
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name na ON ci.person_id = na.person_id
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        person_info pi ON ci.person_id = pi.person_id
    WHERE 
        a.production_year >= 2000
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id, k.keyword
),

RankedMovies AS (
    SELECT 
        md.*,
        DENSE_RANK() OVER (PARTITION BY md.production_year ORDER BY md.company_count DESC, md.info_count DESC) AS rank
    FROM 
        MovieDetails md
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.keyword,
    rm.cast_names,
    rm.company_count,
    rm.info_count,
    rm.rank
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year, rm.rank;
