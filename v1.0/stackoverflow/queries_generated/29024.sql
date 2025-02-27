WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body
), 
UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        Users u
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
FinalReport AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        us.TotalScore,
        us.TotalPosts,
        ra.HistoryCount,
        ra.LastActivityDate,
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.VoteCount,
        rp.CreationDate AS PostCreationDate
    FROM 
        UserScore us
    JOIN 
        RecentActivity ra ON us.UserId = ra.UserId
    LEFT JOIN 
        RankedPosts rp ON us.UserId = rp.OwnerPostRank
    WHERE 
        us.TotalScore > 1000
    ORDER BY 
        us.TotalScore DESC, ra.LastActivityDate DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalScore,
    TotalPosts,
    HistoryCount,
    LastActivityDate,
    PostId,
    Title,
    CommentCount,
    VoteCount,
    PostCreationDate
FROM 
    FinalReport
WHERE 
    LastActivityDate >= NOW() - INTERVAL '3 months'
LIMIT 50;
