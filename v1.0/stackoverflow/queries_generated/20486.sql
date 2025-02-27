WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) FILTER (WHERE c.UserId IS NOT NULL) OVER (PARTITION BY p.Id) AS CommentCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(b.Name, ', ') AS Badges,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPostsByBadgedUser AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ru.UserId,
        bu.Badges,
        bu.AvgReputation,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        BadgedUsers bu ON u.Id = bu.UserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        rp.rn <= 3
    GROUP BY 
        rp.PostId, ru.UserId, bu.Badges, bu.AvgReputation
),
FinalOutput AS (
    SELECT 
        tpb.PostId,
        tpb.Title,
        tpb.Badges,
        tpb.AvgReputation,
        ranking.Score,
        ranking.CommentCount,
        COALESCE(ranking.ViewCount, 0) + COALESCE(tpb.CommentCount, 0) AS TotalInteraction
    FROM 
        TopPostsByBadgedUser tpb
    JOIN 
        RankedPosts ranking ON tpb.PostId = ranking.PostId
    ORDER BY 
        TotalInteraction DESC
)
SELECT 
    fo.PostId,
    fo.Title,
    fo.Badges,
    fo.AvgReputation,
    fo.ViewCount,
    fo.CommentCount,
    fo.TotalInteraction
FROM 
    FinalOutput fo
WHERE 
    fo.TotalInteraction > 10
OR 
    (fo.TotalInteraction IS NULL AND fo.Badges IS NOT NULL)
ORDER BY 
    fo.AvgReputation DESC, fo.PostId;

This SQL query does the following:

1. **Common Table Expressions (CTEs)**: 
   - `RankedPosts` ranks posts by their creation date while counting their comments and calculating upvotes and downvotes.
   - `BadgedUsers` aggregates badges for users and calculates average reputation.
   - `TopPostsByBadgedUser` joins the post data and user badges, limiting to the top-ranked posts and counting comments.

2. **Subqueries**: Used for counting votes in `RankedPosts`.

3. **Window functions**: `ROW_NUMBER()` to rank posts and `COUNT()` as a window function to count comments.

4. **Filter logic**: Handles NULLs using `COALESCE`, applying complex filters for the final selection.

5. **String aggregate**: Uses `STRING_AGG` to concatenate badge names.

This query exemplifies various SQL capabilities and employs NULL logic, intricate joins, and noteworthy performance benchmarks while obeying the peculiarities and relationships within the schema.
