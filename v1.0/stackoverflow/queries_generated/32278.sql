WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]))) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.Rank,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.Tags,
        COALESCE((
            SELECT 
                ARRAY_AGG(b.Name)
            FROM 
                Badges b 
            JOIN 
                Users u ON b.UserId = u.Id
            WHERE 
                u.Id = p.OwnerUserId
            GROUP BY 
                u.Id
        ), ARRAY[]::varchar[]) AS UserBadges
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    f.PostId,
    f.Title,
    f.Score,
    f.ViewCount,
    f.CreationDate,
    f.CommentCount,
    f.UpVoteCount,
    f.DownVoteCount,
    f.Tags,
    f.UserBadges
FROM 
    FilteredPosts f
ORDER BY 
    f.Score DESC, f.ViewCount DESC
LIMIT 10;

This SQL query performs the following tasks:

1. It creates two Common Table Expressions (CTEs) to rank posts and filter them based on specific criteria.
2. The `RankedPosts` CTE ranks posts by their score and creation date, aggregates comment count, and counts upvotes and downvotes.
3. It also extracts associated tags by using a correlated subquery.
4. The `FilteredPosts` CTE retrieves the top 5 posts by rank while aggregating badges associated with the post owner.
5. Finally, it selects the most relevant details for these filtered posts and orders them by score and view count, limiting the results to the top 10 posts. 

This query incorporates outer joins, window functions, correlated subqueries, string operations, and NULL logic, all while aiming for performance benchmarking on the Stack Overflow schema.
