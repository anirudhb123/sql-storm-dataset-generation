WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rnk
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
        AND p.ViewCount IS NOT NULL
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

QuestionStats AS (
    SELECT 
        p.Id AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2::smallint) AS UpVotes,
        SUM(v.VoteTypeId = 3::smallint) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 -- Answers
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),

ActiveUserPosts AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews 
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate < NOW() - INTERVAL '1 year' -- Active users
    GROUP BY 
        u.Id
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, '; ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate < NOW() - INTERVAL '30 days'
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    ub.TotalBadges,
    ub.BadgeNames,
    qs.AnswerCount,
    qs.UpVotes,
    qs.DownVotes,
    uup.TotalPosts,
    uup.TotalViews,
    ph.LastEditDate,
    ph.HistoryTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ub.UserId)
LEFT JOIN 
    QuestionStats qs ON rp.PostId = qs.QuestionId
LEFT JOIN 
    ActiveUserPosts uup ON uup.UserId = (SELECT DISTINCT p.OwnerUserId FROM Posts p WHERE p.Id = rp.PostId)
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rnk <= 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC, 
    ub.TotalBadges DESC;
