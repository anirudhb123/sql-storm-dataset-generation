WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length -- Assuming info_type_id = 1 is general info
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        kind_id, 
        actors,
        keywords,
        company_count,
        avg_info_length,
        ROW_NUMBER() OVER (ORDER BY production_year DESC, company_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    t.movie_id,
    t.title,
    t.production_year,
    t.kind_id,
    t.actors,
    t.keywords,
    t.company_count,
    t.avg_info_length
FROM 
    TopMovies t
WHERE 
    rank <= 10
ORDER BY 
    t.rank;
