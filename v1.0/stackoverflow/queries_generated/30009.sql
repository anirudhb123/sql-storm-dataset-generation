WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > 0
),
UserVotingStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u 
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 8)
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    p.Score AS PostScore,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS UserDisplayName,
    u.TotalVotes,
    ph.EditCount,
    ph.LastEditDate,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open' 
    END AS PostStatus,
    STRING_AGG(t.TagName, ', ') AS TagsList
FROM 
    RankedPosts p
JOIN 
    Users u ON p.UserId = u.Id
LEFT JOIN 
    PostHistoryCounts ph ON p.PostId = ph.PostId
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS tag_array ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tag_array) 
WHERE 
    p.Rank <= 10
GROUP BY 
    p.PostId, u.DisplayName, p.Score, p.ViewCount, p.AnswerCount, ph.EditCount, ph.LastEditDate
ORDER BY 
    p.Score DESC, p.CreationDate DESC;
