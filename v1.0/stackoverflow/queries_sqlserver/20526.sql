
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        AVG(CASE WHEN v.VoteTypeId IN (8, 9) THEN v.BountyAmount END) OVER (PARTITION BY u.Id) AS AvgBounty
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 1000
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COALESCE(p.ViewCount, 0) AS TotalViews,
        COALESCE(p.AnswerCount, 0) AS TotalAnswers,
        COALESCE(p.CommentCount, 0) AS TotalComments,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId
)
SELECT 
    pm.PostId,
    pm.OwnerUserId,
    pm.TotalViews,
    pm.TotalAnswers,
    pm.TotalComments,
    pm.LastEdited,
    pm.EditCount,
    um.UserRank,
    um.Reputation,
    um.AvgBounty,
    CASE 
        WHEN pm.TotalAnswers > 0 THEN CONVERT(float, pm.TotalAnswers) / NULLIF(pm.TotalViews, 0) 
        ELSE 0 
    END AS AnswerToViewRatio,
    CASE 
        WHEN pm.EditCount > 0 THEN pm.TotalComments / NULLIF(pm.EditCount, 0) 
        ELSE NULL 
    END AS CommentToEditRatio
FROM PostMetrics pm
JOIN UserMetrics um ON pm.OwnerUserId = um.UserId
WHERE um.UserRank <= 100
ORDER BY pm.TotalViews DESC, um.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
