WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounties
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only Questions
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5 -- users with more than 5 posts
),
PostHistoryAnalysis AS (
    SELECT
        ph.PostId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        pha.EditCount,
        pha.CloseReopenCount,
        COALESCE(mu.QuestionCount, 0) AS ActiveUserQuestions,
        COALESCE(mu.TotalBounties, 0) AS TotalUserBounties
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryAnalysis pha ON rp.PostId = pha.PostId
    LEFT JOIN 
        MostActiveUsers mu ON mu.UserId = rp.OwnerDisplayName
)
SELECT 
    fm.*,
    (fm.Score * 1.0 / NULLIF(fm.CommentCount, 0)) AS ScoreToCommentRatio,
    CASE 
        WHEN fm.CloseReopenCount > 0 THEN 'Has been closed or reopened'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN fm.ActiveUserQuestions > 10 THEN 'Active Contributor'
        ELSE 'Regular User'
    END AS UserStatus
FROM 
    FinalMetrics fm
ORDER BY 
    fm.Score DESC, fm.ViewCount DESC;
