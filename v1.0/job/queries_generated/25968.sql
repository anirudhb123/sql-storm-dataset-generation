WITH RankedTitles AS (
    SELECT 
        a.title, 
        a.id AS movie_id, 
        a.production_year, 
        k.keyword,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
), 
PopularActors AS (
    SELECT 
        ac.person_id, 
        COUNT(DISTINCT ac.movie_id) AS movies_count
    FROM 
        cast_info ac
    GROUP BY 
        ac.person_id
    HAVING 
        COUNT(DISTINCT ac.movie_id) > 10
), 
MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        COALESCE(n.name, 'Unknown') AS director_name,
        COALESCE(c.name, 'Unknown Company') AS company_name,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
    LEFT JOIN 
        person_info pi ON mi.id = pi.id
    LEFT JOIN 
        name n ON pi.person_id = n.imdb_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.title, t.production_year, n.name, c.name
    HAVING 
        COUNT(DISTINCT mk.keyword_id) > 1
)
SELECT 
    rt.title, 
    rt.production_year,
    pa.movies_count AS actor_movies_count,
    md.keyword_count AS keyword_count
FROM 
    RankedTitles rt
JOIN 
    PopularActors pa ON pa.person_id IN (SELECT DISTINCT person_id FROM cast_info WHERE movie_id = rt.movie_id)
JOIN 
    MovieDetails md ON rt.movie_id = md.movie_id
WHERE 
    rt.year_rank <= 3
ORDER BY 
    rt.production_year DESC, md.keyword_count DESC, actor_movies_count DESC;
