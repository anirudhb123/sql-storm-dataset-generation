WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS TotalUpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS TotalDownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate
),
UserPostInteraction AS (
    SELECT 
        u.UserId,
        p.PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS UserDisplayName,
        ups.TotalUpVotes,
        ups.TotalDownVotes,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.TotalBounty
    FROM 
        UserVoteSummary ups
    JOIN 
        Posts p ON ups.UserId = p.OwnerUserId
    LEFT JOIN 
        PostSummary ps ON p.Id = ps.PostId
)

SELECT 
    upi.UserDisplayName,
    upi.PostId,
    upi.Title,
    upi.CreationDate,
    upi.TotalUpVotes,
    upi.TotalDownVotes,
    upi.CommentCount,
    upi.UpVoteCount,
    upi.DownVoteCount,
    upi.TotalBounty
FROM 
    UserPostInteraction upi
WHERE 
    upi.TotalVotes > 10
ORDER BY 
    upi.CreationDate DESC
LIMIT 100;
