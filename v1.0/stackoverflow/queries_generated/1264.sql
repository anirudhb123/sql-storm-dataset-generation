WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVotes, 0) AS UpVotes
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes 
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
MostCommented AS (
    SELECT 
        PostId, 
        Title,
        CommentCount 
    FROM RankedPosts 
    WHERE CommentCount > 10
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM Posts
    WHERE PostTypeId = 1
),
TagStats AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM PopularTags
    GROUP BY Tag
    HAVING COUNT(*) > 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Rank,
    rp.Score,
    rp.ViewCount,
    mc.CommentCount,
    ts.Tag,
    CONCAT('https://example.com/posts/', rp.PostId) AS PostUrl
FROM RankedPosts rp
JOIN MostCommented mc ON rp.PostId = mc.PostId
JOIN TagStats ts ON ts.Tag IN (SELECT UNNEST(string_to_array(rp.Tags, '><')))
WHERE rp.Rank <= 5
ORDER BY rp.Score DESC, rp.ViewCount ASC;
