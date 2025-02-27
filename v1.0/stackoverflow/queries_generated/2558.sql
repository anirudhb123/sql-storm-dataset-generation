WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.AcceptedAnswerId IS NOT NULL
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.UpVotes,
        us.DownVotes,
        RANK() OVER (ORDER BY us.UpVotes - us.DownVotes DESC) AS UserRank
    FROM 
        UserStatistics us
    WHERE 
        us.BadgeCount > 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserId,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY ph.UserId ORDER BY ph.CreationDate DESC) AS ClosureRank
    FROM 
        PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore,
    rp.ViewCount AS PostViewCount,
    rp.AnswerCount AS TotalAnswers,
    tu.DisplayName AS TopUser,
    tu.UpVotes AS UserUpVotes,
    tu.DownVotes AS UserDownVotes,
    cp.Comment AS ClosureComment,
    cp.CreationDate AS ClosureDate
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tu ON rp.AnswerCount > 0
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.Id AND cp.ClosureRank = 1
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
