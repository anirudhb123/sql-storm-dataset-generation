
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
        AND u.Reputation > 0
), 
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId
), 
PostDetails AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.CommentCount DESC) AS UserPostRank,
        pt.Name AS PostType,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        PostSummary ps
    JOIN PostTypes pt ON ps.PostTypeId = pt.Id
    LEFT JOIN Posts p ON ps.PostId = p.Id
    LEFT JOIN (
        SELECT 
            pb.Id AS PostId,
            SUBSTRING(pb.Tags, 2, CHAR_LENGTH(pb.Tags) - 2) AS Tags
        FROM 
            Posts pb
    ) AS tagData ON tagData.PostId = ps.PostId
    LEFT JOIN (
        SELECT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName
        FROM 
            (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6) numbers
        WHERE 
            CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    ) AS t ON FIND_IN_SET(t.TagName, tagData.Tags)
    GROUP BY 
        ps.PostId, ps.OwnerUserId, ps.CommentCount, ps.UpVoteCount, ps.DownVoteCount, ps.TotalBounty, pt.Name
)

SELECT 
    u.DisplayName,
    u.Reputation,
    p.PostId,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    p.TotalBounty,
    p.PostType,
    p.Tags,
    CASE 
        WHEN p.CommentCount IS NULL THEN 'No comments yet'
        ELSE CONCAT('This post has ', p.CommentCount, ' comments.')
    END AS CommentStatus,
    CASE 
        WHEN u.UserId IS NULL THEN 'User not found'
        ELSE (SELECT Name FROM PostHistoryTypes WHERE Id = (SELECT MAX(PostHistoryTypeId) FROM PostHistory WHERE PostId = p.PostId))
    END AS LastActionType
FROM 
    RankedUsers u
JOIN 
    PostDetails p ON u.UserId = p.OwnerUserId
WHERE 
    u.UserRank <= 10
ORDER BY 
    u.UserRank, p.CommentCount DESC;
