WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        r.role,
        p.name AS person_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS rank
    FROM 
        title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    WHERE 
        m.production_year >= 2000
        AND r.role IS NOT NULL
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT co.name) AS company_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        m.movie_id
),
HighRankedMovies AS (
    SELECT 
        mm.*,
        mi.keywords,
        mi.company_count
    FROM 
        RankedMovies mm
    JOIN 
        MovieInfo mi ON mm.movie_id = mi.movie_id
    WHERE 
        mm.rank <= 5
)
SELECT 
    h.title,
    h.keywords,
    h.company_count, 
    COUNT(*) OVER() AS total_high_ranked_movies
FROM 
    HighRankedMovies h
WHERE 
    h.company_count > 1
ORDER BY 
    h.title;
