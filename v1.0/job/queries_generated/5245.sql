WITH MovieStatistics AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS num_actors,
        AVG(y.production_year) AS avg_production_year
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        person_info pi ON c.person_id = pi.person_id
    JOIN 
        name n ON pi.person_id = n.imdb_id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        aka_name an ON n.id = an.person_id
    LEFT JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        t.id, t.title
)
SELECT 
    movie_id, 
    title, 
    num_actors, 
    avg_production_year,
    (SELECT COUNT(*) FROM movie_keyword WHERE movie_id = MovieStatistics.movie_id) AS num_keywords
FROM 
    MovieStatistics
WHERE 
    num_actors > 10 
ORDER BY 
    avg_production_year DESC, num_actors DESC;
