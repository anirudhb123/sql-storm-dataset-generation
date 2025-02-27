WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(cc.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(cc.id) DESC) AS rank_by_cast
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.cast_count
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank_by_cast <= 3
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        c.movie_id,
        tt.title,
        tt.production_year
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        TopTitles tt ON c.movie_id = tt.title_id
)
SELECT 
    tt.title,
    tt.production_year,
    STRING_AGG(ad.actor_name, ', ') AS actor_names
FROM 
    TopTitles tt
JOIN 
    ActorDetails ad ON tt.title_id = ad.movie_id
GROUP BY 
    tt.title, tt.production_year
ORDER BY 
    tt.production_year DESC, tt.title;

### Explanation:
1. **RankedTitles**: This CTE calculates the number of actors in each title and ranks titles based on the cast count for each production year.
2. **TopTitles**: This CTE retrieves the top 3 titles by cast count for each production year.
3. **ActorDetails**: This CTE gathers actor names associated with the top titles.
4. The final SELECT statement fetches the title, production year, and concatenated actor names for each title from the TopTitles, ordering the results by production year and title. 

This query benchmarks string processing through the use of `STRING_AGG` to combine actor names into a single string, assessing performance in handling string operations across multiple related datasets.
