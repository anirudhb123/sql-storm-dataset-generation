WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS QuestionCount,
        SUM(CommentCount) AS TotalComments,
        SUM(VoteCount) AS TotalVotes
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) >= 3
)
SELECT 
    u.DisplayName, 
    t.QuestionCount, 
    t.TotalComments, 
    t.TotalVotes
FROM 
    TopUsers t
JOIN 
    Users u ON t.OwnerUserId = u.Id
ORDER BY 
    t.TotalVotes DESC, 
    t.TotalComments DESC;
