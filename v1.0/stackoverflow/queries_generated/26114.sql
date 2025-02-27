WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        MAX(pv.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes pv ON pv.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, u.DisplayName
),
RankedPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Tags,
        fp.CreationDate,
        fp.OwnerDisplayName,
        fp.CommentCount,
        fp.AnswerCount,
        fp.LastVoteDate,
        RANK() OVER (ORDER BY fp.CommentCount DESC, fp.AnswerCount DESC, fp.CreationDate DESC) AS PostRank
    FROM 
        FilteredPosts fp
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.AnswerCount,
    TO_CHAR(rp.CreationDate, 'YYYY-MM-DD HH24:MI:SS') AS FormattedCreationDate,
    TO_CHAR(rp.LastVoteDate, 'YYYY-MM-DD HH24:MI:SS') AS FormattedLastVoteDate,
    CASE
        WHEN rp.CommentCount > 10 THEN 'High Engagement'
        WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.PostRank;
