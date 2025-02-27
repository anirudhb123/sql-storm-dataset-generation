WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(COALESCE(v.Score, 0)) AS TotalVotes,
        AVG(v.VoteTypeId) AS AverageVoteType -- Converting VoteTypeId to Analytical Metric
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeList
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges only
    GROUP BY 
        b.UserId
)
SELECT 
    ra.UserId,
    ra.DisplayName,
    ra.QuestionsAsked,
    ra.TotalVotes,
    ra.AverageVoteType,
    COALESCE(phc.EditCount, 0) AS EditCount,
    COALESCE(phc.LastEditDate, 'N/A') AS LastEditDate,
    COALESCE(ub.BadgeList, 'No Gold Badges') AS GoldBadges,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount
FROM 
    RecentActivity ra
LEFT JOIN 
    PostHistoryCounts phc ON ra.UserId = phc.PostId
LEFT JOIN 
    UserBadges ub ON ra.UserId = ub.UserId
LEFT JOIN 
    RankedPosts rp ON ra.UserId = rp.PostId
WHERE 
    ra.QuestionsAsked > 5
ORDER BY 
    ra.TotalVotes DESC, 
    ra.DisplayName ASC;
