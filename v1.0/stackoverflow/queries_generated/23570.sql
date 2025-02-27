WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
        AND p.PostTypeId = 1 -- Only questions
),

UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),

QuestionCloseDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        STRING_AGG(ct.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON ph.Comment::int = ct.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.UserId, ph.CreationDate
),

UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ' | ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

FinalOutput AS (
    SELECT 
        up.UserId,
        p.PostId,
        p.Title,
        up.Reputation,
        up.TotalScore,
        ub.BadgeNames,
        ub.BadgeCount,
        COALESCE(qc.CloseReasonNames, 'No close reasons') AS CloseReasons,
        p.RN
    FROM 
        RankedPosts p
    JOIN 
        UserScore up ON p.OwnerUserId = up.UserId
    LEFT JOIN 
        UserBadges ub ON up.UserId = ub.UserId
    LEFT JOIN 
        QuestionCloseDetails qc ON p.PostId = qc.PostId
    WHERE 
        p.RN <= 5 -- Top 5 recent questions per user
      AND 
        up.TotalScore > 0 -- Users who have at least one score
)

SELECT 
    u.DisplayName,
    fo.PostId,
    fo.Title,
    fo.Reputation,
    fo.TotalScore,
    fo.BadgeNames,
    fo.BadgeCount,
    fo.CloseReasons
FROM 
    FinalOutput fo
JOIN 
    Users u ON fo.UserId = u.Id
ORDER BY 
    fo.Reputation DESC, 
    fo.TotalScore DESC
OPTION (RECOMPILE);
