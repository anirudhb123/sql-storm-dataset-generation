WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.PostTypeId,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    AND 
        p.PostTypeId IN (1, 2)  -- Considering only Questions and Answers
),
PostViewCounts AS (
    SELECT 
        PostId,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    GROUP BY 
        PostId
),
BadgesSummary AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    WHERE 
        Date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        UserId
),
FilteredBadges AS (
    SELECT 
        ub.UserId,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        BadgesSummary ub
    WHERE 
        ub.BadgeCount > 5  -- Only users with more than 5 badges in the last year
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.Reputation,
    COALESCE(pvc.TotalViews, 0) AS TotalViews,
    fb.BadgeCount,
    fb.BadgeNames,
    CASE 
        WHEN rp.PostTypeId = 1 AND rp.Score > 10 THEN 'Highly Active Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostCategory,
    CASE 
        WHEN rp.ViewCount IS NULL OR rp.ViewCount = 0 THEN 'No Views'
        ELSE 'Has Views'
    END AS ViewStatus
FROM 
    RecentPosts rp
LEFT JOIN 
    PostViewCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN 
    FilteredBadges fb ON fb.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    EXISTS (
        SELECT 1 
        FROM Comments c 
        WHERE c.PostId = rp.PostId 
        AND c.CreationDate >= CURRENT_DATE - INTERVAL '7 days'
    )
ORDER BY 
    rp.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;

-- A composite expression to illustrate NULL logic and unusual semantics:
SELECT 
    CASE 
        WHEN COUNT(NULLIF(QuestionCount, 0)) = 0 THEN 'No Questions Found'
        ELSE 'Questions Exist'
    END AS QuestionStatus,
    ARRAY_AGG(DISTINCT TagName) AS UniqueTags
FROM (
    SELECT 
        pt.Id AS PostTypeId,
        COUNT(*) AS QuestionCount,
        t.TagName
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pt.Name = 'Question'
    GROUP BY 
        pt.Id, t.TagName
) sub
