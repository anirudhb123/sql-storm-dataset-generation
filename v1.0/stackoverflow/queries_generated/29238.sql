WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.Body,
        p.CreationDate,
        p.Score,
        STRING_AGG(t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(PH.Id) AS EditCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Tags tg ON tg.Id = ANY (STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')::int[])
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Users U ON U.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON PH.PostId = p.Id AND PH.PostHistoryTypeId IN (4, 5, 6) -- Title, Body or Tags Edited
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, U.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.Tags,
        rp.CommentCount,
        rp.EditCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10 -- Top 10 posts by Score
)

SELECT 
    p.Title,
    p.Score,
    p.Tags,
    p.CommentCount,
    p.EditCount,
    p.OwnerDisplayName,
    CASE 
        WHEN p.EditCount > 5 THEN 'Frequently Edited'
        WHEN p.EditCount BETWEEN 3 AND 5 THEN 'Moderately Edited'
        ELSE 'Rarely Edited'
    END AS EditFrequency,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.PostId AND v.VoteTypeId = 2) AS UpVoteCount, -- Count of UpVotes
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.PostId AND v.VoteTypeId = 3) AS DownVoteCount -- Count of DownVotes
FROM 
    TopPosts p
ORDER BY 
    p.Score DESC;
