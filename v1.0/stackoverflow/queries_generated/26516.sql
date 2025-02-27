WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1  -- Only questions
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, u.Reputation
),
TopTags AS (
    SELECT 
        Tags,
        COUNT(*) AS PostCount
    FROM RankedPosts
    WHERE TagRank <= 5  -- Top 5 tagged questions
    GROUP BY Tags
    ORDER BY PostCount DESC
),
PopularPosts AS (
    SELECT 
        rp.*,
        tt.PostCount
    FROM RankedPosts rp
    JOIN TopTags tt ON rp.Tags = tt.Tags
    WHERE rp.TagRank <= 5
    ORDER BY rp.ViewCount DESC
)
SELECT 
    pp.PartitioningTag,
    pp.PostId,
    pp.Title,
    pp.OwnerDisplayName,
    pp.OwnerReputation,
    pp.ViewCount,
    pp.Score,
    pp.CommentCount,
    pp.VoteCount,
    pp.CreationDate
FROM (
    SELECT 
        Tags AS PartitioningTag,
        PostId,
        Title,
        OwnerDisplayName,
        OwnerReputation,
        ViewCount,
        Score,
        CommentCount,
        VoteCount,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY Tags ORDER BY ViewCount DESC, Score DESC) AS TagPostRank
    FROM PopularPosts
) pp
WHERE pp.TagPostRank <= 3  -- Top 3 posts per tag
ORDER BY pp.PartitioningTag, pp.ViewCount DESC;

This query benchmarks string processing by focusing on questions (PostTypeId = 1), analyzing their performance based on tags, view counts, and scores. The query retrieves top questions per tag, counting their comments and votes, while also considering the owner's reputation for further analytics. It employs Common Table Expressions (CTEs) to isolate tasks and calculate ranks effectively, making it structured and efficient for benchmarking.
