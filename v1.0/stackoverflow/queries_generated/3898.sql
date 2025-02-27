WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        u.DisplayName,
        ua.VoteCount AS UserVoteCount,
        ua.UpVotes,
        ua.DownVotes,
        ua.AverageViewCount 
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserActivity ua ON ua.UserId = (SELECT 
                                            TOP 1 Id 
                                        FROM 
                                            Users 
                                        ORDER BY 
                                            Reputation DESC)
    JOIN 
        Users u ON u.Id = (SELECT 
                            TOP 1 OwnerUserId 
                            FROM 
                            Posts 
                            WHERE 
                            Id = rp.PostId)
    WHERE 
        rp.PostRank = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.DisplayName AS Owner,
    COALESCE(tp.UserVoteCount, 0) AS TotalVotes,
    COALESCE(tp.UpVotes, 0) AS TotalUpVotes,
    COALESCE(tp.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN tp.AverageViewCount IS NULL THEN 'No views available'
        ELSE 'Average views - ' || ROUND(tp.AverageViewCount, 2)::text 
    END AS AverageViewText
FROM 
    TopPosts tp
UNION ALL
SELECT 
    NULL AS PostId,
    'Aggregate Statistics' AS Title,
    NULL AS CreationDate,
    NULL AS ViewCount,
    NULL AS Owner,
    SUM(UserVoteCount) AS TotalVotes,
    SUM(UpVotes) AS TotalUpVotes,
    SUM(DownVotes) AS TotalDownVotes,
    NULL AS AverageViewText
FROM 
    TopPosts
ORDER BY 
    TotalVotes DESC NULLS LAST;
