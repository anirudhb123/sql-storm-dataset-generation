WITH RecursivePostTree AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level,
        p.CreationDate,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        pt.Level + 1,
        p.CreationDate,
        p.OwnerUserId
    FROM 
        Posts p
    INNER JOIN RecursivePostTree pt ON p.ParentId = pt.Id
    WHERE 
        p.PostTypeId = 2  -- Answers
),
PostScores AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(UPVotes - DownVotes, 0) AS NetScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(d.Id) AS Downvotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes d ON p.Id = d.PostId AND d.VoteTypeId = 3  -- Downvotes
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, UVotes, DownVotes
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(pv.UPVotes) AS TotalUpVotes,
        SUM(pv.DownVotes) AS TotalDownVotes,
        DENSE_RANK() OVER (ORDER BY SUM(pv.UPVotes) DESC) AS UserRank
    FROM
        Users u
    LEFT JOIN
        Posts pv ON u.Id = pv.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),
FinalOutput AS (
    SELECT 
        pt.Title AS QuestionTitle,
        pt.NetScore,
        pt.CommentCount,
        pt.BadgeCount,
        pt.RelatedPostCount,
        tu.UserRank,
        tu.DisplayName AS TopUser,
        COALESCE(ct.CloseReasonName, 'Not Closed') AS CloseReason
    FROM 
        PostScores pt
    LEFT JOIN
        (SELECT DISTINCT 
            ph.PostId,
            cr.Name AS CloseReasonName
         FROM 
            PostHistory ph
         JOIN 
            CloseReasonTypes cr ON ph.Comment = cr.Id
         WHERE 
            ph.PostHistoryTypeId = 10) ct ON pt.Id = ct.PostId
    JOIN 
        TopUsers tu ON pt.OwnerUserId = tu.UserId
)
SELECT 
    *
FROM 
    FinalOutput
ORDER BY 
    NetScore DESC, 
    CommentCount DESC;
