WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(p.Tags, '<>') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_array
    WHERE 
        p.PostTypeId = 1  -- only questions
    GROUP BY 
        p.Id, u.DisplayName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostScore AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Owner,
        rp.CreationDate,
        rp.Score + ue.UpVoteCount - ue.DownVoteCount AS AdjustedScore,
        rp.ViewCount,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    JOIN 
        UserEngagement ue ON rp.Owner = ue.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Owner,
    ps.CreationDate,
    ps.AdjustedScore,
    ps.ViewCount,
    ps.CommentCount,
    ps.Tags
FROM 
    PostScore ps
WHERE 
    ps.AdjustedScore > 0
ORDER BY 
    ps.AdjustedScore DESC, ps.ViewCount DESC
LIMIT 10;

This SQL query performs the following operations:

1. **Ranks Posts**: The `RankedPosts` Common Table Expression (CTE) aggregates data from the `Posts`, `Users`, `Comments`, and `Tags` tables to rank the questions based on their total comment count, score, and view count. It also constructs a comma-separated list of unique tags associated with each question.

2. **Calculates User Engagement**: The `UserEngagement` CTE aggregates user voting data to compute total bounties and counts of upvotes and downvotes per user.

3. **Adjusts Post Scores**: The `PostScore` CTE computes an "AdjustedScore" for each post by adding its score to the user's upvote counts and subtracting downvote counts.

4. **Final Selection**: The outer query selects the top 10 posts based on the `AdjustedScore` and views, filtering for posts with a positive score. The results include the post ID, title, owner, date, adjusted score, view count, comment count, and associated tags.
