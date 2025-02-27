WITH ActorMovies AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    GROUP BY 
        a.person_id, a.name
), 
HighestRevenue AS (
    SELECT 
        mc.movie_id,
        SUM(m.info) AS revenue
    FROM 
        movie_companies mc
    JOIN 
        movie_info m ON mc.movie_id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
    GROUP BY 
        mc.movie_id
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
    HAVING 
        COUNT(mk.keyword_id) > 5
)
SELECT 
    am.name AS actor_name,
    am.movie_count,
    am.movies,
    hr.revenue AS box_office_revenue,
    pk.keyword_count AS popular_keywords
FROM 
    ActorMovies am
LEFT JOIN 
    HighestRevenue hr ON am.movie_count > 5 AND am.person_id IN (SELECT person_id FROM cast_info WHERE movie_id IN (SELECT movie_id FROM PopularKeywords))
LEFT JOIN 
    PopularKeywords pk ON am.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = pk.movie_id)
WHERE 
    am.movie_count IS NOT NULL
ORDER BY 
    hr.revenue DESC, am.movie_count DESC;
