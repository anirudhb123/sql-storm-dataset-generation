WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(DISTINCT tags.TagName) AS Tags,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            ID, 
            UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS TagName 
         FROM 
            Posts) tags ON p.Id = tags.ID
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        rp.AnswerCount,
        rp.CommentCount,
        tu.DisplayName AS TopUserName
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers tu ON rp.UserPostRank <= 3
    WHERE 
        rp.Score > 10
)
SELECT 
    pp.*,
    COALESCE(ph.Comment, 'No History') AS PostHistoryComment,
    TO_CHAR(ph.CreationDate, 'YYYY-MM-DD HH24:MI:SS') AS HistoryDateFormatted
FROM 
    PopularPosts pp
LEFT JOIN 
    PostHistory ph ON pp.PostId = ph.PostId AND ph.PostHistoryTypeId = 10 -- Post Closed history
ORDER BY 
    pp.Score DESC, 
    pp.ViewCount DESC;
