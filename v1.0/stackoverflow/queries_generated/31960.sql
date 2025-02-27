WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT SUBSTRING(t.TagName FROM 1 FOR 35)) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.VoteCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VotesGiven
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
AggregatedUserActivity AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostsCreated,
        ua.CommentsMade,
        ua.VotesGiven,
        CASE 
            WHEN ua.VotesGiven IS NULL THEN 'No votes given' 
            ELSE CASE 
                WHEN ua.VotesGiven > 100 THEN 'High Activity'
                WHEN ua.VotesGiven > 50 THEN 'Medium Activity'
                ELSE 'Low Activity'
            END
        END AS ActivityLevel
    FROM 
        UserActivity ua
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.Tags,
    aua.DisplayName,
    aua.PostsCreated,
    aua.CommentsMade,
    aua.VotesGiven,
    aua.ActivityLevel
FROM 
    TopPosts tp
JOIN 
    AggregatedUserActivity aua ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = aua.UserId)
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
