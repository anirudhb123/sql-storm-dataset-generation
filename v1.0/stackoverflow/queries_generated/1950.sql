WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Only Questions
        p.CreationDate > current_date - interval '1 year' -- From the last year
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON u.Id = c.UserId 
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 2
    GROUP BY 
        u.Id
), 
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN ph.Text 
            ELSE NULL 
        END) AS LastCloseReason
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalQuestions,
    ua.TotalComments,
    ua.UpVotesReceived,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    pha.EditCount,
    pha.LastEditDate,
    pha.LastCloseReason
FROM 
    UserActivity ua
JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryAnalysis pha ON rp.PostId = pha.PostId
WHERE 
    rp.Rank <= 5 -- Top 5 posts per user
ORDER BY 
    ua.TotalQuestions DESC, ua.UpVotesReceived DESC, rp.Score DESC;
