WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId AND c.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(*) AS TotalPosts
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEdited,
        STRING_AGG(CASE 
            WHEN ph.PostHistoryTypeId IN (4, 5) THEN 'Edited: ' || ph.Comment 
            ELSE 'Other Action' END, '; ') AS HistoryComments
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        ph.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    up.VoteCount,
    COALESCE(pd.LastEdited, 'Never Edited') AS LastEdited,
    pd.HistoryComments
FROM 
    TopUsers u
LEFT JOIN 
    (
        SELECT 
            v.UserId,
            COUNT(v.Id) AS VoteCount
        FROM 
            Votes v
        JOIN 
            Posts p ON v.PostId = p.Id
        WHERE 
            v.VoteTypeId IN (2, 3) -- Upvotes and Downvotes
            AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        GROUP BY 
            v.UserId
    ) up ON u.UserId = up.UserId
LEFT JOIN 
    PostHistoryDetails pd ON pd.PostId IN (
        SELECT 
            rp.Id
        FROM 
            RankedPosts rp
        WHERE 
            rp.UserRank <= 5
    )
WHERE 
    u.TotalPosts > 5
ORDER BY 
    u.Reputation DESC,
    up.VoteCount DESC NULLS LAST;

