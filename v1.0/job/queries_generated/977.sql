WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY SUM(ci.nr_order) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(AVG(mi.info::float), 0) AS avg_rating,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
), CombinedDetails AS (
    SELECT 
        md.title,
        md.production_year,
        md.avg_rating,
        md.keyword_count,
        COALESCE((
            SELECT COUNT(DISTINCT c.id)
            FROM complete_cast cc
            JOIN cast_info c ON cc.subject_id = c.person_id
            WHERE cc.movie_id = md.movie_id
        ), 0) AS total_cast
    FROM 
        MovieDetails md
)
SELECT 
    cd.title,
    cd.production_year,
    cd.avg_rating,
    cd.keyword_count,
    cd.total_cast,
    CASE 
        WHEN cd.avg_rating IS NULL THEN 'No Rating'
        ELSE ROUND(cd.avg_rating, 2)::text 
    END AS formatted_rating,
    CONCAT('Movie: ', cd.title, ', Year: ', cd.production_year) AS movie_description
FROM 
    CombinedDetails cd
ORDER BY 
    cd.production_year DESC, cd.avg_rating DESC
LIMIT 10;
