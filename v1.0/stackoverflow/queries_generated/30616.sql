WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)), 0) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1
),
PostHistoryWithTags AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag::int = t.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(U.UpVotes - U.DownVotes) AS NetVotes
    FROM 
        Users U
    GROUP BY 
        U.Id
    ORDER BY 
        NetVotes DESC
    LIMIT 10
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    pht.Tags,
    rp.VoteCount,
    u.DisplayName AS TopUserDisplayName,
    u.NetVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryWithTags pht ON rp.Id = pht.PostId
LEFT JOIN 
    TopUsers u ON u.NetVotes > 50 -- Only considering top users with net votes greater than 50
WHERE 
    rp.PostRank = 1 AND -- Get the latest post of each user
    rp.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created within the last year
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
