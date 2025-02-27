
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', ''))) / LENGTH('><') + 1 AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR 
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        TagCount,
        OwnerDisplayName,
        OwnerReputation
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 100 
),
PostVoteCount AS (
    SELECT 
        PostId, 
        SUM(VoteTypeId = 2) AS UpVotes, 
        SUM(VoteTypeId = 3) AS DownVotes 
    FROM 
        Votes 
    GROUP BY 
        PostId
),
PostWithVotes AS (
    SELECT 
        trp.*,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        PostVoteCount pvc ON trp.PostId = pvc.PostId
)
SELECT 
    pwv.PostId,
    pwv.Title,
    pwv.CreationDate,
    pwv.Score,
    pwv.ViewCount,
    pwv.TagCount,
    pwv.OwnerDisplayName,
    pwv.OwnerReputation,
    pwv.UpVotes,
    pwv.DownVotes,
    (pwv.UpVotes - pwv.DownVotes) AS NetVotes,
    TIMESTAMPDIFF(SECOND, pwv.CreationDate, '2024-10-01 12:34:56') / 3600 AS HoursSinceCreation
FROM 
    PostWithVotes pwv
WHERE 
    pwv.UpVotes > pwv.DownVotes 
ORDER BY 
    NetVotes DESC, pwv.Score DESC;
