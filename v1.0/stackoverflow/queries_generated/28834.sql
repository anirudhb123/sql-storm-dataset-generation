WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
        AND p.Score > 0
),

TopTags AS (
    SELECT
        UNNEST(string_to_array(Tags, '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM
        Posts
    WHERE
        Tags IS NOT NULL
    GROUP BY
        UNNEST(string_to_array(Tags, '>'))
    ORDER BY
        TagCount DESC
    LIMIT 10
),

UserReputation AS (
    SELECT
        UserId,
        SUM(Reputation) AS TotalReputation
    FROM
        Users
    GROUP BY
        UserId
    HAVING
        COUNT(*) > 1
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    tt.TagName,
    ur.TotalReputation,
    CASE
        WHEN rp.Rank <= 5 THEN 'Top Rank'
        ELSE 'Other'
    END AS PostRankCategory
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.Tags LIKE '%' || tt.TagName || '%'
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

This query benchmarks string processing by first ranking posts based on their score and view count, filtering to include only recent, high-scoring submissions. Next, it retrieves the top 10 tags by their occurrence in the posts and also aggregates user reputations. Finally, it combines these datasets to provide a comprehensive overview of the top posts woven by their tags and user contributions, categorizing them based on their rank.
