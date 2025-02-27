WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, -1) AS AnswerStatus,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- UpMod and DownMod
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS TagArray ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TagArray
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate, p.AcceptedAnswerId
),
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        TagList,
        AnswerStatus,
        CommentCount,
        VoteCount,
        LEAD(VoteCount) OVER (ORDER BY VoteCount DESC) AS NextVoteCount,
        LAG(VoteCount) OVER (ORDER BY VoteCount DESC) AS PrevVoteCount,
        ROW_NUMBER() OVER (ORDER BY VoteCount DESC) AS Rank
    FROM 
        FilteredPosts
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.TagList,
    ps.AnswerStatus,
    ps.CommentCount,
    ps.VoteCount,
    (ps.VoteCount - COALESCE(ps.PrevVoteCount, 0)) AS VoteDifferenceFromPrev,
    (COALESCE(ps.NextVoteCount, 0) - ps.VoteCount) AS VoteDifferenceToNext,
    ROUND(100.0 * (ps.VoteCount::float / NULLIF(SUM(ps.VoteCount) OVER (), 0)), 2) AS VotePercentage
FROM 
    PostStatistics ps
ORDER BY 
    ps.Rank
LIMIT 100;
