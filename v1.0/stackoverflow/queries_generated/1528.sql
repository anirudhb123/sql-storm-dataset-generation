WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UserReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        pc.CommentCount,
        CASE 
            WHEN tp.UserReputation > 1000 THEN 'Expert'
            WHEN tp.UserReputation BETWEEN 500 AND 1000 THEN 'Intermediate'
            ELSE 'Novice'
        END AS UserLevel
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    COALESCE(fr.CommentCount, 0) AS TotalComments,
    fr.UserLevel
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC
LIMIT 10;

SELECT 
    TagName, 
    COUNT(*) AS PostCount 
FROM 
    Tags t 
JOIN 
    Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[]) 
GROUP BY 
    TagName 
HAVING 
    COUNT(*) > 100
ORDER BY 
    PostCount DESC;

WITH PopularUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
    HAVING 
        UpVotesCount - DownVotesCount > 50
)
SELECT 
    pu.UserId,
    pu.DisplayName,
    pu.UpVotesCount,
    pu.DownVotesCount,
    (pu.UpVotesCount - pu.DownVotesCount) AS NetVotes
FROM 
    PopularUsers pu
ORDER BY 
    NetVotes DESC
LIMIT 5;
