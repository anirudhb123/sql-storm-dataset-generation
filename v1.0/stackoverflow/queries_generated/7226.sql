WITH RankedPosts AS (
    SELECT 
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(*) AS PostCount,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
    GROUP BY 
        OwnerDisplayName
)
SELECT 
    OwnerDisplayName,
    PostCount,
    TotalUpVotes,
    TotalDownVotes,
    ROUND(COALESCE(TotalUpVotes, 0) * 1.0 / NULLIF(PostCount, 0), 2) AS AverageUpVotesPerPost,
    ROUND(COALESCE(TotalDownVotes, 0) * 1.0 / NULLIF(PostCount, 0), 2) AS AverageDownVotesPerPost
FROM 
    TopUsers
ORDER BY 
    PostCount DESC
LIMIT 10;
