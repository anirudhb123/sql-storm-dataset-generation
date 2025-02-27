WITH 
    RankedTitles AS (
        SELECT 
            a.title,
            a.production_year,
            k.keyword,
            RANK() OVER (PARTITION BY k.keyword ORDER BY a.production_year DESC) AS ranking
        FROM 
            aka_title a 
        JOIN 
            movie_keyword mk ON a.id = mk.movie_id
        JOIN 
            keyword k ON mk.keyword_id = k.id
    ),
    ActorRoleCounts AS (
        SELECT 
            ci.person_id,
            COUNT(DISTINCT ci.movie_id) AS movie_count,
            STRING_AGG(DISTINCT rt.role, ', ') AS roles
        FROM 
            cast_info ci 
        JOIN 
            role_type rt ON ci.person_role_id = rt.id
        GROUP BY 
            ci.person_id
    ),
    PopularActors AS (
        SELECT 
            ak.id,
            ak.name,
            ak.md5sum,
            arc.movie_count,
            arc.roles
        FROM 
            aka_name ak
        JOIN 
            ActorRoleCounts arc ON ak.person_id = arc.person_id
        WHERE 
            arc.movie_count > 10
    )
SELECT 
    pt.title,
    pt.production_year,
    pa.name AS actor_name,
    pa.movie_count,
    pa.roles,
    STRING_AGG(DISTINCT pt.keyword, ', ') AS associated_keywords
FROM 
    RankedTitles pt
JOIN 
    PopularActors pa ON pt.ranking = 1
GROUP BY 
    pt.title, pt.production_year, pa.name, pa.movie_count, pa.roles
ORDER BY 
    pt.production_year DESC, pt.title;

This SQL query benchmarks string processing by performing multiple joins and aggregations across various tables in the schema. It creates several Common Table Expressions (CTEs) to rank titles by production year, count unique movies per actor while gathering their roles, and filter for popular actors. The final output compiles and organizes titles, years, actors' names, and associated keywords, simulating complex string processing and data aggregation tasks common in analytical queries.
