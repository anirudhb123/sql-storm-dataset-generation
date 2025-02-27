
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag_names
         FROM 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
          SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag_names ON TRUE
    LEFT JOIN 
        Tags t ON tag_names = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName, u.Reputation
),
VoteStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        PostId
),
CommentCount AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostHistoryCount AS (
    SELECT 
        PostId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.Tags,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(cc.TotalComments, 0) AS TotalComments,
    COALESCE(phc.HistoryCount, 0) AS PostHistoryCount
FROM 
    PostDetails pd
LEFT JOIN 
    VoteStatistics vs ON pd.PostId = vs.PostId
LEFT JOIN 
    CommentCount cc ON pd.PostId = cc.PostId
LEFT JOIN 
    PostHistoryCount phc ON pd.PostId = phc.PostId
ORDER BY 
    pd.Score DESC, 
    pd.ViewCount DESC;
