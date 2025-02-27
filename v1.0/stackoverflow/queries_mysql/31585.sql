
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
RecentVotes AS (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes
    WHERE 
        CreationDate >= NOW() - INTERVAL 1 MONTH
    GROUP BY 
        PostId
),
PostsWithHistory AS (
    SELECT 
        p.Id,
        ph.UserDisplayName,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ph.PostHistoryTypeId
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.LastActivityDate >= NOW() - INTERVAL 3 MONTH
        AND ph.PostHistoryTypeId IN (10, 12)  
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.CreationDate AS QuestionDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rv.VoteCount,
    rv.UpVoteCount,
    rv.DownVoteCount,
    CASE 
        WHEN pwh.UserDisplayName IS NOT NULL THEN CONCAT('Closed/Deleted by: ', pwh.UserDisplayName)
        ELSE 'No close/delete history'
    END AS CloseReason,
    pwh.HistoryDate
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    PostsWithHistory pwh ON rp.PostId = pwh.Id
WHERE 
    rp.Rank <= 5  
ORDER BY 
    rp.OwnerDisplayName, rp.Score DESC;
