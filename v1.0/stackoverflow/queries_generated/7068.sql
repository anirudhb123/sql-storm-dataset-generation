WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
        AND p.Score > 0
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    us.DisplayName AS Author,
    us.BadgeCount,
    us.TotalBounty,
    us.UpVoteCount,
    us.DownVoteCount,
    us.AcceptedAnswers
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostId = p.Id
JOIN 
    Users us ON p.OwnerUserId = us.Id
WHERE 
    rp.Rank <= 100 -- Get top 100 recent questions with score
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC;
