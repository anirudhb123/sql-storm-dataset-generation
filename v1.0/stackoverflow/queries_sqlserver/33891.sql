
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS APPLY 
        (SELECT value AS TagName FROM STRING_SPLIT(p.Tags, '>')) t
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.OwnerUserId
),
RecentUserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(ISNULL(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS PostCount,
        MAX(p.Score) AS MaxPostScore,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '1 year'
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 50 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryAnalysis AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS EditComments,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS TotalCloseHistory
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.TotalBounties,
    ru.PostCount,
    ru.MaxPostScore,
    ru.LastActivity,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score AS PostScore,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    pha.LastEditDate,
    pha.EditComments,
    pha.TotalCloseHistory,
    CASE 
        WHEN pha.TotalCloseHistory > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RecentUserEngagement ru
JOIN 
    RankedPosts rp ON ru.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryAnalysis pha ON rp.PostId = pha.PostId
WHERE 
    rp.RankByUser = 1 
ORDER BY 
    ru.Reputation DESC, 
    ru.PostCount DESC, 
    rp.Score DESC;
