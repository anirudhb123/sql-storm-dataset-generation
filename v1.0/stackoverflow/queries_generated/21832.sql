WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
QuestionStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        RankedPosts rp
),
TagPostCounts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(pt.PostId) AS AssociatedPosts
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        t.Id, t.TagName
),
ClosedPostDetails AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    qs.PostId,
    qs.Title,
    qs.OwnerDisplayName,
    qs.CreationDate,
    qs.ViewCount,
    qs.Score,
    qs.CommentCount,
    qs.UpVotes,
    qs.DownVotes,
    COALESCE(cpd.ClosedDate, 'Not Closed') AS ClosedDate,
    COALESCE(cpd.ClosedBy, 'N/A') AS ClosedBy,
    COALESCE(cpd.CloseReason, 'N/A') AS CloseReason,
    tc.TagId,
    tc.TagName,
    tc.AssociatedPosts
FROM 
    QuestionStats qs
LEFT JOIN 
    ClosedPostDetails cpd ON qs.PostId = cpd.PostId
LEFT JOIN 
    TagPostCounts tc ON tc.TagId IN (SELECT unnest(string_to_array(qs.Tags, ','))::int)
WHERE 
    qs.CommentCount > 0 -- Only questions with comments
ORDER BY 
    qs.ViewCount DESC, qs.Score ASC, tc.AssociatedPosts DESC NULLS LAST
LIMIT 100;

-- Query involves:
-- 1. CTEs for organizing data into structured subsets.
-- 2. Subqueries for aggregates within the CTEs.
-- 3. COALESCE for NULL handling.
-- 4. LEFT JOINs to capture all questions, regardless of closed or tagged status.
-- 5. Using string manipulation applied to the Tags column.
-- 6. Combining results for posts, comments, user interaction, and tag relations.
-- 7. Complicated predicates and sorting based on multiple criteria.
