WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        -- Not counting votes on deleted posts
        COUNT(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswerCount
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId
),

FilteredPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.AcceptedAnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1  -- only keep latest post per user
        AND rp.CommentCount > 0
        AND rp.AcceptedAnswerCount = 0  -- We are looking for questions without accepted answers
),

PostTags AS (
    SELECT
        p.Id AS PostID,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM
        Posts p
        JOIN PostsTags pt ON p.Id = pt.PostId
        JOIN Tags t ON pt.TagId = t.Id
    GROUP BY
        p.Id
)

SELECT 
    fp.PostID,
    fp.Title,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    pt.Tags,
    CASE WHEN CAST(fp.UpVotes AS FLOAT) / NULLIF(fp.DownVotes, 0) > 2 THEN 'Hot' ELSE 'Normal' END AS PostHeat,
    COALESCE(fp.UpVotes - fp.DownVotes, 0) AS VoteBalance,
    CASE WHEN fp.CommentCount > 10 THEN 'Highly Discussed' ELSE 'Less Discussed' END AS DiscussionLevel
FROM 
    FilteredPosts fp
    LEFT JOIN PostTags pt ON fp.PostID = pt.PostID
ORDER BY 
    VoteBalance DESC,
    fp.CommentCount DESC
LIMIT 100;

-- Additional performance comparison with outer join to include orphaned posts
LEFT JOIN (SELECT Id FROM Posts WHERE OwnerUserId IS NULL) AS OrphanedPosts ON fp.PostID = OrphanedPosts.Id
WHERE OrphanedPosts.Id IS NULL
AND fp.CommentCount > 0
WITH ORDINALITY;

This SQL query captures several advanced concepts, including CTEs, window functions, conditional aggregation, string manipulation, and handling of NULL values. It focuses on gathering data on recent questions without accepted answers, filtering and aggregating data before presenting a final summary that indicates post "heat" and discussion level. An outer join loosely integrates orphaned posts into the main result set, showcasing possible issues with posts lacking clear ownership.
