WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 -- Only users with significant reputation
),
UserPosts AS (
    SELECT 
        ru.UserId,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers ru ON rp.PostRank = 1 AND rp.OwnerUserId = ru.UserId -- Only top recent question for each top user
    GROUP BY 
        ru.UserId
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
PostHistories AS (
    SELECT 
        ph.PostId,
        pt.Name AS PostHistoryType,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year' -- Only recent histories
    GROUP BY 
        ph.PostId, pt.Name
),
AggregatedData AS (
    SELECT 
        up.UserId,
        up.TotalPosts,
        up.TotalScore,
        up.AvgViewCount,
        pc.CommentCount,
        COALESCE(SUM(ph.HistoryCount), 0) AS TotalHistoryChanges
    FROM 
        UserPosts up
    LEFT JOIN 
        PostComments pc ON up.UserId = pc.PostId
    LEFT JOIN 
        PostHistories ph ON up.UserId = ph.PostId
    GROUP BY 
        up.UserId, up.TotalPosts, up.TotalScore, up.AvgViewCount, pc.CommentCount
)

SELECT 
    u.DisplayName,
    u.Reputation,
    ad.TotalPosts,
    ad.TotalScore,
    ad.AvgViewCount,
    ad.CommentCount,
    ad.TotalHistoryChanges
FROM 
    TopUsers u
JOIN 
    AggregatedData ad ON u.UserId = ad.UserId
WHERE 
    ad.TotalPosts > 0
ORDER BY 
    u.UserRank, ad.TotalScore DESC, ad.TotalPosts DESC;
