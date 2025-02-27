WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
CommentsSummary AS (
    SELECT 
        PostId,
        AVG(Score) AS AvgCommentScore,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10)
    GROUP BY 
        ph.PostId, ph.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    ub.BadgeCount,
    ub.MaxBadgeClass,
    pt.Tag,
    cs.AvgCommentScore,
    cs.TotalComments,
    phd.LastEditDate,
    phd.EditComments
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PopularTags pt ON rp.PostId IN (SELECT PostId FROM Posts WHERE Tags LIKE '%' || pt.Tag || '%')
LEFT JOIN 
    CommentsSummary cs ON rp.PostId = cs.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.Rank <= 5 -- Top 5 posts per user
ORDER BY 
    rp.Score DESC, 
    rp.CommentCount DESC;
