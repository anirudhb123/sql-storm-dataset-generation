WITH ranked_actors AS (
    SELECT
        ca.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) as actor_rank
    FROM
        cast_info ca
    JOIN
        aka_name a ON ca.person_id = a.person_id
),
movie_info_details AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(mi.info, 'No information') AS movie_info,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
    FROM
        aka_title m
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON m.id = ci.movie_id
    GROUP BY
        m.id, m.title, mi.info
),
highly_rated_movies AS (
    SELECT
        m.movie_id,
        m.movie_title,
        m.movie_info,
        m.keyword_count,
        m.avg_order,
        RANK() OVER (ORDER BY m.keyword_count DESC) as rank_by_keywords
    FROM
        movie_info_details m
    WHERE
        m.keyword_count > 5
),
actor_statistics AS (
    SELECT
        r.actor_name,
        COUNT(*) AS movies_count,
        SUM(CASE WHEN h.rank_by_keywords IS NOT NULL THEN 1 ELSE 0 END) AS hit_high_keywords
    FROM
        ranked_actors r
    LEFT JOIN
        highly_rated_movies h ON r.movie_id = h.movie_id
    GROUP BY
        r.actor_name
),
final_evaluation AS (
    SELECT
        a.actor_name,
        a.movies_count,
        a.hit_high_keywords,
        CASE 
            WHEN a.hit_high_keywords > 0 THEN 'Top Performer'
            ELSE 'Needs Improvement'
        END AS performance_evaluation
    FROM
        actor_statistics a
    WHERE
        a.movies_count > 1
)
SELECT
    fe.actor_name,
    fe.movies_count,
    fe.hit_high_keywords,
    fe.performance_evaluation
FROM
    final_evaluation fe
ORDER BY
    fe.hit_high_keywords DESC, fe.movies_count DESC;
